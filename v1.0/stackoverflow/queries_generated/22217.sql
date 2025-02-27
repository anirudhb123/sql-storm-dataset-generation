WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COALESCE(
            (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 
            0
        ) AS TotalUpVotes,
        COALESCE(
            (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 
            0
        ) AS TotalDownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
),
HistoricalPostStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN cr.Name END, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    LEFT JOIN 
        CloseReasonTypes cr ON ph.Comment::INT = cr.Id -- Casting, assuming valid integers in Comment
    GROUP BY 
        ph.PostId
),
RankedPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.ViewCount,
        pd.Score,
        pd.CommentCount,
        hps.EditCount,
        hps.LastEditDate,
        hps.CloseReasons,
        RANK() OVER (ORDER BY pd.Score DESC, pd.CommentCount DESC NULLS LAST) AS RankScore
    FROM 
        PostDetails pd
    LEFT JOIN 
        HistoricalPostStats hps ON pd.PostId = hps.PostId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.UpVotes,
    us.DownVotes,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.CommentCount,
    rp.EditCount,
    rp.LastEditDate,
    rp.CloseReasons
FROM 
    UserStats us
LEFT JOIN 
    RankedPosts rp ON  
        us.UpVotes > 10 AND 
        (us.DownVotes < 5 OR us.Reputation > 1000) -- Obscure filtering condition
WHERE 
    rp.RankScore <= 50 -- top 50 posts
ORDER BY 
    us.DisplayName, rp.Score DESC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY; -- Pagination: skip first 10 results and then fetch the next 10
