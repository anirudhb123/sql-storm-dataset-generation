WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(DISTINCT c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS UpVotes,
        SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
        AND p.Score IS NOT NULL
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalScore,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        RANK() OVER (ORDER BY TotalScore DESC) AS UserRank
    FROM 
        UserStatistics
)
SELECT 
    u.DisplayName,
    u.PostCount,
    u.TotalScore,
    u.GoldBadges,
    u.SilverBadges,
    u.BronzeBadges,
    COALESCE(rp.Title, 'No Posts') AS TopPostTitle,
    COALESCE(rp.Score, 0) AS TopPostScore,
    rp.CommentCount,
    u.UserRank
FROM 
    TopUsers u
LEFT JOIN 
    RankedPosts rp ON u.UserId = rp.OwnerUserId AND rp.PostRank = 1
WHERE 
    u.PostCount > 0
ORDER BY 
    u.TotalScore DESC, u.UserRank;
