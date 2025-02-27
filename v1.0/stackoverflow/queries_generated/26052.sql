WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankByCreationDate
    FROM 
        Posts p
    INNER JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Considering only questions
    GROUP BY 
        p.Id, U.DisplayName
),

TopUserPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        RankByCreationDate = 1
)

SELECT 
    t.DisplayName AS TopUser,
    t.Reputation,
    STRING_AGG(p.Title, ', ') AS TopPosts,
    STRING_AGG(p.Tags, ', ') AS Tags
FROM 
    Users t
JOIN 
    (SELECT 
        OwnerDisplayName, 
        Reputation, 
        COUNT(PostId) AS PostCount 
     FROM 
        TopUserPosts 
     GROUP BY 
        OwnerDisplayName, Reputation 
     HAVING 
        COUNT(PostId) > 3) AS user_post_counts ON t.DisplayName = user_post_counts.OwnerDisplayName
JOIN 
    TopUserPosts p ON t.DisplayName = p.OwnerDisplayName
GROUP BY 
    t.DisplayName, t.Reputation
ORDER BY 
    t.Reputation DESC;
