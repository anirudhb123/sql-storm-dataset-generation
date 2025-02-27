WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) as UserPostRank
    FROM 
        Posts p
    WHERE 
        p.ViewCount > 100
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(b.Count, 0) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN (
        SELECT UserId, COUNT(*) AS Count
        FROM Badges
        GROUP BY UserId
    ) b ON b.UserId = u.Id
    WHERE 
        u.Reputation >= 100
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS LastOpenedDate,
        COUNT(ph.Id) FILTER (WHERE ph.PostHistoryTypeId = 24) AS EditCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
ScoreAnalysis AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        ur.Reputation,
        ur.BadgeCount,
        COALESCE(ph.LastClosedDate, '1970-01-01') AS LastClosed,
        COALESCE(ph.LastOpenedDate, '1970-01-01') AS LastOpened,
        ph.EditCount,
        CASE
            WHEN ph.LastClosedDate IS NULL THEN 'Open'
            WHEN ph.LastOpenedDate > ph.LastClosedDate THEN 'Reopened'
            ELSE 'Closed'
        END AS PostStatus
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    JOIN 
        PostHistoryDetails ph ON rp.PostId = ph.PostId
)
SELECT 
    s.Title,
    s.Score,
    s.Reputation,
    s.BadgeCount,
    s.PostStatus,
    (SELECT COUNT(*) 
     FROM Comments c 
     WHERE c.PostId = s.PostId 
     AND CAST(c.CreationDate AS DATE) BETWEEN '2023-01-01' AND CURRENT_DATE
    ) AS RecentCommentCount,
    CASE 
        WHEN s.Score > 0 THEN 'Positive Score'
        WHEN s.Score < 0 THEN 'Negative Score'
        ELSE 'Neutral Score'
    END AS ScoreCategory,
    STRING_AGG(t.TagName, ', ') AS TagsList
FROM 
    ScoreAnalysis s
LEFT JOIN 
    Posts p ON s.PostId = p.Id
LEFT JOIN 
    LATERAL (
        SELECT UNNEST(string_to_array(p.Tags, ',')) AS TagName
    ) t ON TRUE
WHERE 
    s.UserPostRank <= 5
    AND s.Reputation BETWEEN 150 AND 1000
GROUP BY 
    s.Title, s.Score, s.Reputation, s.BadgeCount, s.PostStatus, s.PostId
ORDER BY 
    s.Score DESC, s.Reputation DESC
LIMIT 50;

This query performs several operations including:
1. CTEs to rank posts by their creation date per user, calculate user reputation and badge counts, and analyze post history for closed/opened statuses and edit counts.
2. It utilizes window functions to assign ranks to posts.
3. It incorporates lateral joins with string manipulation to extract tags from a post.
4. Conditional logic using case statements to evaluate post status and score categories.
5. Aggregation to count recent comments and group tags into a list.
