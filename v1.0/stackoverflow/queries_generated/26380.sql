WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsArray,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tagName ON tagName IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tagName
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
),
UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
ActivitySummary AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 1 THEN 1 ELSE 0 END) AS AcceptedAnswers,
        COUNT(DISTINCT cp.Id) AS CommunityPostsCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Posts cp ON p.Id = cp.ParentId AND cp.PostTypeId = 2 -- Answers related to Questions
    GROUP BY 
        u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.TagsArray,
    ub.BadgeCount,
    ub.GoldBadgeCount,
    ub.SilverBadgeCount,
    ub.BronzeBadgeCount,
    asum.TotalVotes,
    asum.AcceptedAnswers,
    asum.CommunityPostsCount
FROM 
    RankedPosts rp
JOIN 
    UserBadgeCounts ub ON rp.OwnerDisplayName = ub.UserId
JOIN 
    ActivitySummary asum ON rp.OwnerDisplayName = asum.UserId
WHERE 
    rp.UserPostRank <= 5 -- Get top 5 Questions per User
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;
