WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS Author,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Only questions
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.Author,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank = 1  -- Latest post in each tag category
),
TagAggregates AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS Tag,
        COUNT(*) AS PostCount,
        SUM(Score) AS TotalScore,
        SUM(ViewCount) AS TotalViews
    FROM 
        FilteredPosts 
    GROUP BY 
        Tag
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        b.Name AS BadgeName,
        b.Class
    FROM 
        Users u
    JOIN 
        Badges b ON u.Id = b.UserId
)
SELECT 
    fp.Title AS QuestionTitle,
    fp.Author AS QuestionAuthor,
    ta.Tag,
    ta.PostCount,
    ta.TotalScore,
    ta.TotalViews,
    ub.BadgeName,
    ub.Class AS BadgeClass
FROM 
    FilteredPosts fp
JOIN 
    TagAggregates ta ON ta.Tag = ANY(string_to_array(substring(fp.Tags, 2, length(fp.Tags)-2), '><'))
LEFT JOIN 
    UserBadges ub ON ub.UserId = fp.OwnerUserId
ORDER BY 
    ta.PostCount DESC, ta.TotalScore DESC;
This SQL query benchmarks string processing by aggregating relevant information based on tags associated with user-defined questions in the schema. The query identifies the latest question for each tag, calculates how many posts are associated with each tag, totals scores and views, and also collects relevant user badges for the authors of those questions. The result is presented in descending order first by the number of posts per tag and then by their total scores.
