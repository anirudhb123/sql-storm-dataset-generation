WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankByViews,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.AnswerCount DESC) AS RankByAnswers
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only considering Questions
),
PopularTags AS (
    SELECT 
        tag.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Posts p
    JOIN 
        Tags tag ON tag.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '>')::int[])
    WHERE 
        p.PostTypeId = 1 -- Only considering Questions
    GROUP BY 
        tag.TagName
    HAVING 
        COUNT(p.Id) > 5 -- Only tags with more than 5 questions
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(b.Class) AS BadgeCount,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
),
PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CreationDate,
        rp.OwnerUserId,
        rp.OwnerDisplayName,
        pt.TagName,
        ur.DisplayName AS UserName,
        ur.AvgReputation
    FROM 
        RankedPosts rp
    JOIN 
        PostLinks pl ON pl.PostId = rp.PostId
    JOIN 
        PopularTags pt ON pt.TagName = pl.TagType
    JOIN 
        UserReputation ur ON ur.UserId = rp.OwnerUserId 
    WHERE 
        rp.RankByViews <= 5 -- Top 5 posts per user by view count
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.ViewCount,
    pm.AnswerCount,
    pm.CreationDate,
    pm.OwnerDisplayName,
    pm.TagName,
    pm.UserName,
    pm.AvgReputation
FROM 
    PostMetrics pm
ORDER BY 
    pm.ViewCount DESC, pm.AnswerCount DESC;
