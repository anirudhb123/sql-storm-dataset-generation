WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND u.Reputation > 100
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Class = 1 -- Gold badges only
    GROUP BY 
        b.UserId
),
ClosedQuestionStats AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 19) THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (11, 20) THEN 1 END) AS ReopenCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
RelevantTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        REGEXP_SPLIT_TO_TABLE(p.Tags, ', ') AS t(TagName) ON TRUE
    WHERE 
        t.TagName IN ('sql', 'postgresql', 'database') 
    GROUP BY 
        p.Id
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    ub.BadgeNames,
    cqs.CloseCount,
    cqs.ReopenCount,
    rt.Tags
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
LEFT JOIN 
    ClosedQuestionStats cqs ON rp.PostId = cqs.PostId
LEFT JOIN 
    RelevantTags rt ON rp.PostId = rt.PostId
WHERE 
    rp.PostRank <= 5 -- Top 5 posts per type
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;

In this query:
- We first create a Common Table Expression (CTE) called `RankedPosts` to rank posts based on their score and view count. 
- Next, we gather Gold Badges for users and aggregate them into a string for display in `UserBadges`.
- We analyze the `PostHistory` for each post, counting closures and reopenings in the `ClosedQuestionStats` CTE.
- Finally, we extract tags related to specific subjects from the `Posts` table, storing them in `RelevantTags`, and combine all this data in a final SELECT statement that joins these CTEs while filtering for top-ranked posts. 

This intricate use of CTEs, ranking functions, aggregation, and joins demonstrates various SQL constructs and potentially provides interesting performance benchmarking scenarios.
