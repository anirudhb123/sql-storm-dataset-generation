WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS t(TagName)
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(b.Class = 1) AS GoldBadges, -- Count gold badges
        SUM(b.Class = 2) AS SilverBadges, -- Count silver badges
        SUM(b.Class = 3) AS BronzeBadges -- Count bronze badges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),

PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.CommentCount,
        rp.Tags,
        ur.DisplayName AS OwnerDisplayName,
        ur.Reputation AS OwnerReputation,
        ur.TotalPosts,
        ur.GoldBadges,
        ur.SilverBadges,
        ur.BronzeBadges
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.CommentCount,
    ps.Tags,
    ps.OwnerDisplayName,
    ps.OwnerReputation,
    ps.TotalPosts,
    ps.GoldBadges,
    ps.SilverBadges,
    ps.BronzeBadges
FROM 
    PostStatistics ps
WHERE 
    ps.CommentCount > 5 
    AND ps.OwnerReputation > 1000 
    AND ps.PostId IN (SELECT DISTINCT PostId FROM Votes WHERE VoteTypeId = 2) -- Posts that have been upvoted
ORDER BY 
    ps.CreationDate DESC;
