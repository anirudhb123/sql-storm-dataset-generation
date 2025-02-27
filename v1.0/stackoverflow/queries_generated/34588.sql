WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Starting with questions
    UNION ALL
    SELECT 
        a.Id,
        a.Title,
        a.PostTypeId,
        a.Score,
        a.ViewCount,
        a.CreationDate,
        a.OwnerUserId,
        Level + 1
    FROM Posts a
    INNER JOIN RecursivePostCTE r ON a.ParentId = r.PostId
    WHERE a.PostTypeId = 2  -- Answers to those questions
),
PostVoteDetails AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownvoteCount,
        COUNT(v.Id) AS TotalVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
),
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
),
UserSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionsAsked,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswersProvided,
        COALESCE(SUM(b.Class = 1), 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2), 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3), 0) AS BronzeBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
)
SELECT 
    ps.Title AS QuestionTitle,
    ps.Score AS QuestionScore,
    ps.ViewCount AS QuestionViews,
    uv.DisplayName AS UserDisplayName,
    uv.Reputation AS UserReputation,
    COALESCE(vd.UpvoteCount, 0) AS QuestionUpvotes,
    COALESCE(vd.DownvoteCount, 0) AS QuestionDownvotes,
    ts.TagName,
    ts.PostCount,
    ts.TotalViews,
    r.Level AS AnswerLevel
FROM RecursivePostCTE r 
JOIN Posts ps ON r.PostId = ps.Id
JOIN UserSummary uv ON ps.OwnerUserId = uv.UserId
LEFT JOIN PostVoteDetails vd ON ps.Id = vd.PostId
LEFT JOIN TagStatistics ts ON ps.Tags LIKE '%' || ts.TagName || '%'
WHERE ps.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
ORDER BY ps.Score DESC, uv.Reputation DESC, ts.TotalViews DESC;
This SQL query performs several advanced SQL techniques including:

- **Recursive CTE** to gather questions and their associated answers, capturing the hierarchy.
- **Aggregated Vote Details** to show the voting statistics on each post.
- **Tag Statistics** to compute counts of posts and view totals associated with each tag.
- **User Summary** to summarize user activity, including questions and answers with badge counts.
- A main query that combines the data from the CTEs and other calculations to provide a rich dataset focused on recent popular questions and the users who created them. 

The results would give insights into how different users contribute to the community through questions and answers, while also considering voting dynamics and tag-related information.
