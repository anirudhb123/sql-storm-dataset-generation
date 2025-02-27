WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2023-01-01'
    GROUP BY 
        p.Id, u.Reputation
),
AcceptedAnswers AS (
    SELECT 
        p.Id AS QuestionId,
        a.Id AS AcceptedAnswerId
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.AcceptedAnswerId = a.Id
    WHERE 
        p.PostTypeId = 1
),
ClosedPosts AS (
    SELECT 
        p.Id AS ClosedPostId,
        h.CreationDate AS ClosedDate,
        h.PostHistoryTypeId
    FROM 
        Posts p
    JOIN 
        PostHistory h ON p.Id = h.PostId AND h.PostHistoryTypeId IN (10, 11) -- Closed/Reopened
    WHERE 
        h.CreationDate > p.CreationDate
),
TagStats AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.Id, t.TagName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.OwnerReputation,
    rp.Rank,
    COALESCE(c.ClosedPostId, 'Not Closed') AS ClosureStatus,
    COALESCE(c.ClosedDate, CURRENT_TIMESTAMP) AS StatusDate,
    ts.TagName,
    ts.PostCount,
    ts.TotalViews,
    (rp.UpVotes - rp.DownVotes) AS NetVotes,
    CASE
        WHEN rp.Score > 100 THEN 'Highly Liked'
        WHEN rp.Score >= 50 THEN 'Moderately Liked'
        ELSE 'Least Liked'
    END AS LikingCategory,
    (SELECT COUNT(*) FROM AcceptedAnswers a WHERE a.QuestionId = rp.PostId) AS AcceptedAnswerCount
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts c ON rp.PostId = c.ClosedPostId
LEFT JOIN 
    TagStats ts ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.Tags LIKE '%' || ts.TagName || '%')
WHERE 
    rp.Rank = 1 -- Only get the highest ranked post per user
ORDER BY 
    rp.Score DESC,
    rp.CreationDate DESC;
