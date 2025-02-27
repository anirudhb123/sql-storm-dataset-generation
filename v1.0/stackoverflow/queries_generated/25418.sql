WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        pt.Name AS PostType,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, pt.Name
),

TopRatedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.PostType,
        rp.Tags,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
)

SELECT 
    tr.PostId,
    tr.Title,
    tr.PostType,
    tr.Tags,
    tr.CommentCount,
    tr.UpVotes,
    tr.DownVotes,
    (tr.UpVotes - tr.DownVotes) AS NetVotes
FROM 
    TopRatedPosts tr
ORDER BY 
    NetVotes DESC;
