WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        p.Tags,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        COALESCE(pa.AnswerCount, 0) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) pc ON pc.PostId = p.Id
    LEFT JOIN (
        SELECT ParentId, COUNT(*) AS AnswerCount
        FROM Posts 
        WHERE PostTypeId = 2
        GROUP BY ParentId
    ) pa ON pa.ParentId = p.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
        AND p.PostTypeId = 1 -- Questions only
), TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        AVG(u.Reputation) AS AvgUserReputation,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Tags t
    JOIN RecentPosts rp ON rp.Tags LIKE '%' || t.TagName || '%'
    JOIN Users u ON u.Id = rp.OwnerUserId
    GROUP BY 
        t.TagName
), MostActiveTags AS (
    SELECT 
        TagName,
        PostCount,
        AvgUserReputation,
        TotalViews,
        TotalScore,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagStatistics
)
SELECT 
    TagName,
    PostCount,
    AvgUserReputation,
    TotalViews,
    TotalScore
FROM 
    MostActiveTags
WHERE 
    TagRank <= 10
ORDER BY 
    PostCount DESC, TagName;

This query first retrieves recent questions from the `Posts` table, including comment and answer counts. It then aggregates statistics by tags, such as the count of questions, average user reputation, total views, and total score for questions under those tags. Finally, it ranks the tags and returns the top 10 most active tags based on the number of recent questions, ordered by post count.
