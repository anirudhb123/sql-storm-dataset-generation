
WITH PostVoteAggregation AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        pt.Name AS PostType,
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN v.Id END) AS UpVotes,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN v.Id END) AS DownVotes,
        COUNT(CASE WHEN vt.Name = 'Favorite' THEN v.Id END) AS Favorites
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    JOIN 
        VoteTypes vt ON vt.Id = v.VoteTypeId
    JOIN 
        PostTypes pt ON pt.Id = p.PostTypeId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, pt.Name
), TopPostTypes AS (
    SELECT 
        PostType,
        SUM(UpVotes) AS TotalUpVotes
    FROM 
        PostVoteAggregation
    GROUP BY 
        PostType
    ORDER BY 
        TotalUpVotes DESC
    LIMIT 5
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.PostType,
    pa.UpVotes,
    pa.DownVotes,
    pa.Favorites
FROM 
    PostVoteAggregation pa
JOIN 
    TopPostTypes tpt ON pa.PostType = tpt.PostType
ORDER BY 
    pa.UpVotes DESC, pa.Favorites DESC;
