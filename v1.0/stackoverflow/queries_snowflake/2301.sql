
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 10
), 
UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(u.UpVotes) AS TotalUpVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
), 
PostsWithTags AS (
    SELECT 
        p.Id AS PostId,
        pt.Name AS PostType,
        LISTAGG(t.TagName, ', ') WITHIN GROUP (ORDER BY t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        LATERAL SPLIT_TO_TABLE(p.Tags, ',') AS t ON TRUE
    GROUP BY 
        p.Id, pt.Name
)
SELECT 
    r.PostId,
    r.Title,
    r.Score,
    r.CreationDate,
    us.TotalUpVotes,
    us.TotalPosts,
    pwt.PostType,
    pwt.Tags
FROM 
    RankedPosts r
LEFT JOIN 
    UserScores us ON r.OwnerUserId = us.UserId
JOIN 
    PostsWithTags pwt ON r.PostId = pwt.PostId
WHERE 
    r.PostRank <= 3
ORDER BY 
    r.Score DESC
LIMIT 100;
