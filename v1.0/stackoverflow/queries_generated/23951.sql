WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.Score IS NOT NULL
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
ActivePosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RecentHistory
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed or reopened posts
),
VotingData AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        v.CreationDate >= (CURRENT_DATE - INTERVAL '1 month')
    GROUP BY 
        p.Id
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.GoldBadges,
    u.SilverBadges,
    u.BronzeBadges,
    rp.PostId AS BestPostId,
    rp.Title AS BestPostTitle,
    rp.CreationDate AS BestPostCreationDate,
    rp.Score AS BestPostScore,
    ap.CreationDate AS PostStatusChangeDate,
    vd.VoteCount,
    vd.UpVotes,
    vd.DownVotes,
    CASE 
        WHEN rp.ScoreRank = 1 THEN 'Top Post!'
        ELSE 'Keep contributing!'
    END AS ContributionMessage
FROM 
    TopUsers u
LEFT JOIN 
    RankedPosts rp ON u.UserId = rp.OwnerUserId AND rp.ScoreRank = 1
LEFT JOIN 
    ActivePosts ap ON rp.PostId = ap.PostId AND ap.RecentHistory = 1
LEFT JOIN 
    VotingData vd ON rp.PostId = vd.PostId
WHERE 
    (u.GoldBadges + u.SilverBadges + u.BronzeBadges) > 0
    AND (vd.UpVotes IS NOT NULL OR vd.DownVotes IS NOT NULL)
ORDER BY 
    u.Reputation DESC,
    rp.Score DESC NULLS LAST;
