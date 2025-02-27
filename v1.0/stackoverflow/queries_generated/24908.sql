WITH RankedPosts AS (
    SELECT
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM
        Posts p
    WHERE
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserStats AS (
    SELECT
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS Downvotes,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM
        Users u
        LEFT JOIN Votes v ON u.Id = v.UserId
        LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id, u.Reputation, u.DisplayName
),
PostActivity AS (
    SELECT
        ph.PostId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS HistoryCount,
        MAX(ph.CreationDate) AS LastEdited
    FROM
        PostHistory ph
    LEFT JOIN
        Comments c ON ph.PostId = c.PostId
    GROUP BY
        ph.PostId
),
CombinedResults AS (
    SELECT 
        rp.Id AS PostId,
        rp.Title,
        us.DisplayName,
        us.Reputation,
        us.Upvotes,
        us.Downvotes,
        COALESCE(pa.CommentCount, 0) AS CommentCount,
        COALESCE(pa.HistoryCount, 0) AS HistoryCount,
        pa.LastEdited,
        CASE 
            WHEN rp.PostRank <= 5 THEN 'Top Post'
            ELSE 'Regular Post'
        END AS PostCategory
    FROM
        RankedPosts rp
    LEFT JOIN
        UserStats us ON rp.Id = us.UserId
    LEFT JOIN
        PostActivity pa ON rp.Id = pa.PostId
)
SELECT 
    PostId,
    Title,
    DisplayName,
    Reputation,
    Upvotes,
    Downvotes,
    CommentCount,
    HistoryCount,
    LastEdited,
    PostCategory
FROM 
    CombinedResults
WHERE 
    Reputation > (SELECT AVG(Reputation) FROM Users) -- Users above average reputation
    AND LastEdited > CURRENT_DATE - INTERVAL '30 days' -- Posts edited in the last 30 days
ORDER BY 
    Score DESC, 
    LastEdited DESC
LIMIT 10;

