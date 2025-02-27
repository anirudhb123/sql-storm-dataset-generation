WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        p.OwnerUserId,
        u.DisplayName AS PostOwner,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId, u.DisplayName
),
AggregatedUserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUserPosts AS (
    SELECT 
        R.PostId,
        R.PostOwner,
        R.ViewCount,
        R.Score,
        R.CommentCount,
        R.UpVotes,
        R.DownVotes,
        U.TotalPosts,
        U.TotalScore,
        U.GoldBadges
    FROM 
        RankedPosts R
    JOIN 
        AggregatedUserStats U ON R.OwnerUserId = U.UserId
    WHERE 
        R.Rank <= 5
)
SELECT 
    T.PostId,
    T.PostOwner,
    T.ViewCount,
    T.Score,
    T.CommentCount,
    T.UpVotes,
    T.DownVotes,
    T.TotalPosts,
    T.TotalScore,
    COALESCE(NULLIF(T.GoldBadges, 0), 'No Gold Badge') AS GoldBadgeStatus
FROM 
    TopUserPosts T
ORDER BY 
    T.Score DESC, T.ViewCount DESC;

-- Benchmark the performance and execution plan of the above query

