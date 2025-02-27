WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Only considering Questions 
        AND p.CreationDate >= NOW() - INTERVAL '1 year'  -- Only questions created in the last year
        AND p.ViewCount > 100  -- Only questions with more than 100 views
),
TrendingTags AS (
    SELECT 
        unnest(string_to_array(p.Tags, '><')) AS Tag 
    FROM 
        Posts p 
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 month' 
        AND p.PostTypeId = 1
),
TagCounts AS (
    SELECT 
        Tag,
        COUNT(*) AS TagUsage
    FROM 
        TrendingTags 
    GROUP BY 
        Tag 
    ORDER BY 
        TagUsage DESC
    LIMIT 5  -- Top 5 trending tags
),
UserActivities AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsCreated,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.ViewCount,
    rp.OwnerName,
    tg.Tag AS TrendingTag,
    ua.DisplayName AS UserName,
    ua.QuestionsCreated,
    ua.UpVotesReceived,
    ua.DownVotesReceived
FROM 
    RankedPosts rp
JOIN 
    TagCounts tg ON rp.Tags LIKE '%' || tg.Tag || '%'
JOIN 
    UserActivities ua ON rp.OwnerName = ua.DisplayName
WHERE 
    rp.TagRank = 1  -- Get the top rank for each tag
ORDER BY 
    rp.ViewCount DESC, ua.UpVotesReceived DESC;
