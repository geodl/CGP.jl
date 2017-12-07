export CGPChromo, node_genes, get_positions

# vanilla CGP

type CGPChromo <: Chromosome
    genes::Array{Float64}
    nodes::Array{CGPNode}
    outputs::Array{Int64}
    nin::Int64
    nout::Int64
end

function CGPChromo(genes::Array{Float64}, nin::Int64, nout::Int64)::CGPChromo
    num_nodes = Int64(ceil((length(genes)-nin-nout)/4))
    rgenes = reshape(genes[(nin+nout+1):end], (4, num_nodes))'
    connections = Array{Int64}(2, nin+num_nodes)
    connections[:, 1:nin] = zeros(2, nin)
    positions = collect(1:(nin+num_nodes))/(1.0*(nin+num_nodes))
    fc = deepcopy(hcat(zeros(2, nin), [rgenes[:, 2]'; rgenes[:, 3]']))
    if ~Config.recurrency
        for i in nin:length(positions)
            fc[:, i] = (fc[:, i].*(positions[i] - Config.input_start) .+ Config.input_start)
            for j in eachindex(fc[:, i])
                fc[j, i] = max(fc[j,i], positions[i-1])
            end
        end
    end
    connections = snap(fc, positions)
    functions = Array{Function}(nin+num_nodes)
    functions[1:nin] = Config.f_input
    functions[(nin+1):end] = map(i->Config.index_in(Config.functions, i), rgenes[:, 3])
    outputs = Int64.(ceil.(genes[nin+(1:nout)]*(nin+num_nodes)))
    active = find_active(nin, outputs, connections)
    params = [zeros(nin); 2.0*rgenes[:, 4]-1.0]
    nodes = Array{CGPNode}(nin+num_nodes)
    for i in 1:(nin+num_nodes)
        nodes[i] = CGPNode(connections[:, i], functions[i], active[i], params[i])
    end
    CGPChromo(genes, nodes, outputs, nin, nout)
end

function CGPChromo(nin::Int64, nout::Int64)::CGPChromo
    n_nodes = Config.static_node_size
    if Config.bloat()
        n_nodes = Config.starting_nodes
    end
    CGPChromo(rand(nin+nout+4*n_nodes), nin, nout)
end

function CGPChromo(c::CGPChromo)::CGPChromo
    gene_mutate(c)
end

function node_genes(c::CGPChromo)
    4
end

function get_positions(c::CGPChromo)
    collect(1:length(c.nodes))/(1.0*length(c.nodes))
end
