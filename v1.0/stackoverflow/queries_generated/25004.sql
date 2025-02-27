WITH PostWithTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsArray,
        p.CreationDate
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')::int[])
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, u.DisplayName, u.Reputation, p.Title, p.Body, p.CreationDate
),
QuestionStatistics AS (
    SELECT
        pw.PostId,
        pw.Title,
        pw.OwnerDisplayName,
        pw.Reputation,
        pw.CreationDate,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        PostWithTags pw
    LEFT JOIN 
        Posts a ON a.ParentId = pw.PostId -- Answers
    LEFT JOIN 
        Comments c ON c.PostId = pw.PostId -- Comments
    LEFT JOIN 
        Votes v ON v.PostId = pw.PostId AND v.VoteTypeId IN (8, 9) -- Bounty Starts and Ends
    GROUP BY 
        pw.PostId, pw.Title, pw.OwnerDisplayName, pw.Reputation, pw.CreationDate
),
ClosedQuestions AS (
    SELECT 
        ph.PostId,
        ARRAY_AGG(DISTINCT ctr.Name) AS CloseReasons
    FROM 
        PostHistory ph 
    JOIN 
        CloseReasonTypes ctr ON ph.Comment::int = ctr.Id 
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
    GROUP BY 
        ph.PostId
)
SELECT 
    qs.PostId,
    qs.Title,
    qs.OwnerDisplayName,
    qs.Reputation,
    qs.CreationDate,
    qs.AnswerCount,
    qs.CommentCount,
    qs.TotalBounty,
    COALESCE(cq.CloseReasons, ARRAY[]::varchar[]) AS CloseReasons,
    pw.TagsArray
FROM 
    QuestionStatistics qs
LEFT JOIN 
    ClosedQuestions cq ON qs.PostId = cq.PostId
JOIN 
    PostWithTags pw ON qs.PostId = pw.PostId
ORDER BY 
    qs.AnswerCount DESC, qs.TotalBounty DESC;
