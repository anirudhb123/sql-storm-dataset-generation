WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    LEFT JOIN 
        Tags t ON t.Id IN (SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><'))::int)
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, u.DisplayName
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PopularityCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')::int[])
    GROUP BY 
        t.TagName
    ORDER BY 
        PopularityCount DESC
    LIMIT 5
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.Score,
    rp.OwnerDisplayName,
    rp.AnswerCount,
    rp.Tags,
    ua.UserId,
    ua.DisplayName AS UserDisplayName,
    ua.Reputation,
    ua.TotalPosts,
    ua.TotalAnswers,
    ua.GoldBadges,
    ua.SilverBadges,
    ua.BronzeBadges,
    pt.TagName AS MostPopularTag,
    pt.PopularityCount
FROM 
    RankedPosts rp
JOIN 
    UserActivity ua ON rp.PostId IN (SELECT ParentId FROM Posts WHERE PostTypeId = 2)
LEFT JOIN 
    PopularTags pt ON pt.TagName = ANY(rp.Tags)
WHERE 
    rp.UserPostRank = 1
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;
