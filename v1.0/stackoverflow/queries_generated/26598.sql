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
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS t(TagName) ON TRUE
    WHERE 
        p.PostTypeId = 1  -- Considering only Questions
    GROUP BY 
        p.Id, p.Body, p.CreationDate, u.DisplayName    
),
TagCounts AS (
    SELECT 
        TagName,
        COUNT(*) AS TagUsageCount
    FROM 
        UNNEST(ARRAY(SELECT DISTINCT unnest(ARRAY(SELECT string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) FROM Posts WHERE PostTypeId = 1))) AS TagName
    GROUP BY 
        TagName
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
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
    tc.TagUsageCount,
    us.UserId,
    us.DisplayName AS UserDisplayName,
    us.TotalPosts,
    us.TotalUpVotes,
    us.TotalDownVotes,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges
FROM 
    RankedPosts rp
LEFT JOIN 
    TagCounts tc ON tc.TagName = ANY(rp.TagsArray)
JOIN 
    UserStats us ON us.UserId = rp.OwnerDisplayName
WHERE 
    rp.UserPostRank <= 3      -- Filter to include only the latest 3 posts per user
ORDER BY 
    rp.CreationDate DESC;
