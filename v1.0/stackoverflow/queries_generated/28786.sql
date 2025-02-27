WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= DATEADD(year, -1, GETDATE()) -- Within the last year
),
TagUsage AS (
    SELECT
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '>><')) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        Tag
),
MostUsedTags AS (
    SELECT 
        Tag,
        TagCount,
        RANK() OVER (ORDER BY TagCount DESC) AS TagRank
    FROM 
        TagUsage
    WHERE 
        TagCount > 10 -- More than 10 uses
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        AVG(DATEDIFF(MINUTE, p.CreationDate, GETDATE())) AS AvgResponseTime
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.AnswerCount,
    rp.OwnerDisplayName,
    mu.Tag,
    us.TotalAnswers,
    us.TotalQuestions,
    us.AvgResponseTime
FROM 
    RankedPosts rp
JOIN 
    MostUsedTags mu ON mu.Tag = ANY(string_to_array(substring(rp.Tags, 2, length(rp.Tags)-2), '>><')) 
                                    -- Joins to find the most used tags associated with posts by the owner
WHERE 
    rp.PostRank = 1 -- Get only the most recent question for each user
LEFT JOIN 
    UserStatistics us ON rp.OwnerUserId = us.UserId
ORDER BY 
    rp.ViewCount DESC;

