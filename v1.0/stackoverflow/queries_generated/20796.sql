WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3), 0) AS NetVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' AND
        p.PostTypeId IN (1, 2) -- Only Questions and Answers
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
BadgesInfo AS (
    SELECT 
        UserId,
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        bi.GoldBadges,
        bi.SilverBadges,
        bi.BronzeBadges,
        COUNT(p.Id) AS TotalPosts,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        BadgesInfo bi ON u.Id = bi.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, bi.GoldBadges, bi.SilverBadges, bi.BronzeBadges
),
PostRankedUsers AS (
    SELECT 
        r.PostId,
        r.Title,
        u.UserId,
        u.DisplayName,
        r.Rank,
        r.CommentCount,
        r.NetVotes
    FROM 
        RankedPosts r
    JOIN 
        Users u ON r.OwnerUserId = u.Id
    WHERE 
        r.Rank <= 3 -- Top 3 posts per user
)
SELECT 
    u.DisplayName,
    u.Reputation,
    COALESCE(bi.GoldBadges, 0) AS GoldBadges,
    COALESCE(bi.SilverBadges, 0) AS SilverBadges,
    COALESCE(bi.BronzeBadges, 0) AS BronzeBadges,
    SUM(pru.NetVotes) AS TotalNetVotes,
    SUM(pru.CommentCount) AS TotalComments,
    STRING_AGG(pru.Title, '; ') AS TopPosts
FROM 
    UserStatistics bi
LEFT JOIN 
    PostRankedUsers pru ON bi.UserId = pru.UserId
WHERE 
    bi.Reputation > 1000 AND
    (bi.GoldBadges IS NOT NULL OR bi.SilverBadges IS NOT NULL) -- At least one badge
GROUP BY 
    u.DisplayName, u.Reputation, bi.GoldBadges, bi.SilverBadges, bi.BronzeBadges
ORDER BY 
    TotalNetVotes DESC, TotalComments DESC;
