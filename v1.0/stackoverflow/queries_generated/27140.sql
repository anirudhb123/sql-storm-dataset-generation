WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        COUNT(a.Id) AS AnswerCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2 -- Answers
    LEFT JOIN LATERAL unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tagName ON TRUE
    LEFT JOIN Tags t ON t.TagName = tagName
    WHERE p.PostTypeId = 1 -- Questions
    GROUP BY p.Id, u.Id
),

TopAuthors AS (
    SELECT 
        u.Id AS UserID,
        u.DisplayName,
        COUNT(p.Id) AS QuestionCount,
        AVG(p.Score) AS AverageScore,
        SUM(p.ViewCount) AS TotalViews
    FROM Users u
    JOIN Posts p ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 -- Questions
    GROUP BY u.Id
    HAVING COUNT(p.Id) > 10 -- Only consider users with more than 10 questions
),

PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS HistoryDate,
        p.Title AS PostTitle,
        p.Body AS PostBody,
        ph.Comment,
        p.OwnerDisplayName
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    WHERE ph.PostHistoryTypeId IN (4, 5, 6) -- Edits on Title, Body, or Tags
)

SELECT 
    ra.PostID,
    ra.Title,
    ra.OwnerDisplayName,
    ra.CreationDate,
    ra.Score,
    ra.AnswerCount,
    ra.Tags,
    ta.DisplayName AS TopAuthorDisplayName,
    ta.QuestionCount,
    ta.AverageScore,
    ta.TotalViews,
    ph.HistoryDate,
    ph.PostTitle,
    ph.PostBody,
    ph.Comment
FROM RankedPosts ra
JOIN TopAuthors ta ON ra.UserPostRank < 5 
JOIN PostHistoryDetails ph ON ra.PostID = ph.PostId
ORDER BY ra.CreationDate DESC, ra.Score DESC
LIMIT 100;
