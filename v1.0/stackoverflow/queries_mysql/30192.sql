
WITH RecurTagCounts AS (
    SELECT 
        PostId,
        COUNT(DISTINCT Tags) AS TagCount,
        ROW_NUMBER() OVER (PARTITION BY PostId ORDER BY COUNT(DISTINCT Tags) DESC) AS rn
    FROM (
        SELECT 
            Posts.Id AS PostId,
            SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tags
        FROM 
            Posts
        INNER JOIN (
            SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
            UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
            UNION ALL SELECT 9 UNION ALL SELECT 10
        ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
        WHERE 
            Tags IS NOT NULL
    ) AS SubTags
    GROUP BY 
        PostId 
    HAVING 
        COUNT(DISTINCT Tags) > 1
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.Reputation,
        COUNT(c.Id) AS CommentCount,
        COALESCE(v.SilentVote, 0) AS SilentVoteCount
    FROM 
        Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS SilentVote
        FROM 
            Votes 
        WHERE 
            VoteTypeId = 3
        GROUP BY 
            PostId
    ) AS v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 30 DAY
    GROUP BY 
        p.Id, u.Reputation, v.SilentVote
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseReopenCount,
        MAX(ph.CreationDate) AS LastHistoryDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
CombinedResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Reputation,
        rp.CommentCount,
        p.TagCount,
        phd.CloseReopenCount,
        phd.LastHistoryDate
    FROM 
        RecentPosts rp
    JOIN RecurTagCounts p ON rp.PostId = p.PostId
    LEFT JOIN PostHistoryDetails phd ON rp.PostId = phd.PostId
)
SELECT 
    cr.*,
    CASE 
        WHEN cr.CommentCount > 5 THEN 'Active' 
        ELSE 'Less Active' 
    END AS ActivityStatus,
    NULLIF(cr.Reputation, 0) AS UserReputation
FROM 
    CombinedResults cr
ORDER BY 
    cr.CommentCount DESC, cr.CreationDate DESC
LIMIT 100;
