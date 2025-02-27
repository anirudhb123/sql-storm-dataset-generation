WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS TotalAnswers,
        SUM(CASE WHEN a.Score > 0 THEN 1 ELSE 0 END) AS UpvotedAnswers,
        STRING_AGG(DISTINCT t.TagName, ', ') AS LinkedTags,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM p.CreationDate) ORDER BY p.CreationDate DESC) AS YearlyRank
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Posts a ON a.ParentId = p.Id
    LEFT JOIN STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') tag_array ON tag_array.Tag = t.Id
    LEFT JOIN Tags t ON t.TagName = tag_array.Tag
    WHERE p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Score, p.ViewCount, 
        p.AnswerCount, p.CommentCount, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.TotalAnswers,
    rp.UpvotedAnswers,
    rp.LinkedTags,
    rp.YearlyRank,
    COALESCE(b.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(ph.EditCount, 0) AS EditHistoryCount
FROM RankedPosts rp
LEFT JOIN (
    SELECT 
        UserId, 
        COUNT(*) AS BadgeCount 
    FROM Badges 
    GROUP BY UserId
) b ON b.UserId = rp.OwnerUserId
LEFT JOIN (
    SELECT 
        PostId, 
        COUNT(*) AS EditCount 
    FROM PostHistory 
    WHERE PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY PostId
) ph ON ph.PostId = rp.PostId
WHERE rp.YearlyRank <= 5
ORDER BY rp.CreationDate DESC;
