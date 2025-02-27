
WITH UserReputation AS (
    SELECT 
        Id,
        Reputation,
        CASE
            WHEN Reputation >= 10000 THEN 'Elite'
            WHEN Reputation >= 1000 THEN 'Experienced'
            WHEN Reputation >= 100 THEN 'Novice'
            ELSE 'Beginner'
        END AS ReputationLevel
    FROM 
        Users
),
PostScores AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COALESCE(v.Upvotes, 0) - COALESCE(v.Downvotes, 0) AS NetVotes,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
),
CommentAggregates AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount,
        MIN(CreationDate) AS FirstCommentDate,
        MAX(CreationDate) AS LastCommentDate
    FROM 
        Comments
    GROUP BY 
        PostId
),
TagsExploded AS (
    SELECT 
        p.Id AS PostId,
        t.TagName,
        @rownum := IF(@prevPostId = p.Id, @rownum + 1, 1) AS TagPosition,
        @prevPostId := p.Id
    FROM 
        Posts p
    JOIN (
        SELECT 
            SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS TagName
        FROM 
            Posts p JOIN 
            (SELECT a.N + b.N * 10 + 1 n FROM 
                (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a, 
                (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b) n
            ) as numbers on CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1
    ) AS t ON true, 
    (SELECT @rownum := 0, @prevPostId := NULL) r
)
SELECT 
    u.DisplayName,
    u.Reputation,
    ur.ReputationLevel,
    ps.Title,
    ps.Score,
    ps.NetVotes,
    ca.CommentCount,
    ca.FirstCommentDate,
    ca.LastCommentDate,
    te.TagName,
    te.TagPosition
FROM 
    Users u
JOIN 
    UserReputation ur ON u.Id = ur.Id
LEFT JOIN 
    PostScores ps ON u.Id = ps.OwnerUserId
LEFT JOIN 
    CommentAggregates ca ON ps.PostId = ca.PostId
LEFT JOIN 
    TagsExploded te ON ps.PostId = te.PostId AND te.TagPosition <= 3
WHERE 
    (ca.CommentCount > 5 OR ps.Score > 10)
    AND ur.ReputationLevel IN ('Experienced', 'Elite')
ORDER BY 
    ur.Reputation DESC, ps.NetVotes DESC
LIMIT 100 OFFSET 0;
