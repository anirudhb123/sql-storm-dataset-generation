
WITH PostVoteAggregation AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        pt.Name AS PostType,
        COUNT(v.Id) AS UpVotes,
        COUNT(v.Id) AS DownVotes,
        COUNT(v.Id) AS Favorites
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    JOIN 
        VoteTypes vt ON vt.Id = v.VoteTypeId
    JOIN 
        PostTypes pt ON pt.Id = p.PostTypeId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
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
    OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY
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
