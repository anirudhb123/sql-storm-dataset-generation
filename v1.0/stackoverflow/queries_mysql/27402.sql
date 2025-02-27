
WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT 
            p.Id AS PostId,
            SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
        FROM 
            Posts p
        INNER JOIN 
            (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL
             SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL
             SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) t ON t.PostId = p.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR AND 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.AnswerCount 
),
HighEngagementPosts AS (
    SELECT 
        pm.PostId,
        pm.Title,
        pm.ViewCount,
        pm.AnswerCount,
        pm.UpVotes,
        pm.DownVotes,
        pm.Tags,
        (pm.UpVotes - pm.DownVotes) AS NetVotes,
        @row_number := IF(@prev_view_count = pm.ViewCount, @row_number, 0) + 1 AS EngagementRank,
        @prev_view_count := pm.ViewCount
    FROM 
        PostMetrics pm
    CROSS JOIN (SELECT @row_number := 0, @prev_view_count := NULL) AS vars
    WHERE 
        pm.ViewCount > 50 
)

SELECT 
    he.PostId,
    he.Title,
    he.ViewCount,
    he.AnswerCount,
    he.UpVotes,
    he.DownVotes,
    he.NetVotes,
    he.Tags,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    p.LastEditDate
FROM 
    HighEngagementPosts he
JOIN 
    Posts p ON he.PostId = p.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    he.EngagementRank <= 10 
ORDER BY 
    he.EngagementRank;
