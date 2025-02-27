WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        COUNT(DISTINCT tg.TagName) AS TagCount,
        STRING_AGG(DISTINCT tg.TagName, ', ') AS TagsList
    FROM 
        Posts p
    LEFT JOIN 
        UNNEST(string_to_array(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><')) AS tg(TagName)
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id, p.Title, p.Body
), 
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        AVG(COALESCE(p.AcceptedAnswerId IS NOT NULL, 0)::int) AS AcceptanceRate
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
HighScoringPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.AnswerCount,
        p.ViewCount,
        ph.UserDisplayName AS LastEditor,
        ph.CreationDate AS LastEditDate,
        ROW_NUMBER() OVER (PARTITION BY ph.UserId ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.LastEditorUserId = ph.UserId
    WHERE 
        p.PostTypeId = 1 AND p.Score > 10  -- Well-scored questions
)
SELECT 
    u.DisplayName AS UserDisplayName,
    u.PostCount,
    u.TotalViews,
    u.TotalScore,
    u.AcceptanceRate,
    ptc.TagCount,
    ptc.TagsList,
    hsp.Title AS HighScoringPostTitle,
    hsp.Score AS HighScoringPostScore,
    hsp.LastEditor,
    hsp.LastEditDate
FROM 
    UserPostStats u
LEFT JOIN 
    PostTagCounts ptc ON ptc.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.UserId)
LEFT JOIN 
    HighScoringPosts hsp ON hsp.Id IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.UserId)
WHERE 
    u.PostCount > 5  -- Users with more than 5 posts
ORDER BY 
    u.TotalScore DESC, u.TotalViews DESC;
