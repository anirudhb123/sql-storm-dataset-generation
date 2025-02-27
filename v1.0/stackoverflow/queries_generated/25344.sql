WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY SUBSTRING(Tags FROM '\w+') ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  -- Only counting UpVotes
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id, p.Title, p.Tags, p.CreationDate, p.Score, p.ViewCount
),

MostActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
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
    HAVING 
        COUNT(DISTINCT p.Id) > 5  -- Users with more than 5 posts
),

TopTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON POSITION(t.TagName IN p.Tags) > 0
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10  -- Top 10 tags
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Tags,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.VoteCount,
    mu.DisplayName AS TopUser,
    mu.PostCount AS UserPostCount,
    mu.GoldBadges,
    mu.SilverBadges,
    mu.BronzeBadges,
    tt.TagName AS TopTag
FROM 
    RankedPosts rp
LEFT JOIN 
    MostActiveUsers mu ON rp.TagRank = 1  -- Join with top user based on tag rank from RankedPosts
LEFT JOIN 
    TopTags tt ON POSITION(tt.TagName IN rp.Tags) > 0  -- Join with top tags
WHERE 
    rp.Score > 10  -- Only posts with a score greater than 10
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
