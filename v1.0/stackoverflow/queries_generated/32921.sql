WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        1 AS Level,
        ARRAY[p.Id] AS Path
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        c.Level + 1,
        Path || p.Id
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostCTE c ON p.ParentId = c.PostId
), 
PostVoteStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
), 
PopularPosts AS (
    SELECT 
        p.PostId,
        p.Title,
        p.Score + COALESCE(v.UpVotes, 0) - COALESCE(v.DownVotes, 0) AS NetScore,
        p.CreationDate,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        RecursivePostCTE p
    LEFT JOIN 
        PostVoteStats v ON p.PostId = v.PostId
    WHERE 
        p.Level = 1
)
SELECT 
    post_rank.Title,
    post_rank.NetScore,
    post_rank.CreationDate,
    CASE 
        WHEN l.IsModeratorOnly = 1 THEN 'Moderator Only'
        ELSE 'Public'
    END AS Visibility,
    STRING_AGG(t.TagName, ', ') AS Tags,
    array_length(path, 1) AS Depth
FROM 
    PopularPosts post_rank
LEFT JOIN 
    Posts p ON post_rank.PostId = p.Id
LEFT JOIN 
    Tags t ON t.WikiPostId = p.Id
LEFT JOIN 
    Posts l ON l.ParentId = p.Id
WHERE 
    post_rank.Rank <= 10
GROUP BY 
    post_rank.Title, post_rank.NetScore, post_rank.CreationDate, l.IsModeratorOnly, path
ORDER BY 
    post_rank.NetScore DESC, post_rank.CreationDate DESC;
