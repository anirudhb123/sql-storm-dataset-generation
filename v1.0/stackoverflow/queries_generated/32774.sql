WITH RecursivePostCTE AS (
    SELECT Id,
           Title,
           Score,
           ViewCount,
           OwnerUserId,
           AcceptedAnswerId,
           1 AS Level,
           CAST(Title AS VARCHAR(300)) AS FullTitle
    FROM Posts 
    WHERE ParentId IS NULL  -- Top-level questions (no parents)

    UNION ALL

    SELECT p.Id,
           p.Title,
           p.Score,
           p.ViewCount,
           p.OwnerUserId,
           p.AcceptedAnswerId,
           c.Level + 1,
           CAST(c.FullTitle + ' -> ' + p.Title AS VARCHAR(300))
    FROM Posts p
    INNER JOIN RecursivePostCTE c ON p.ParentId = c.Id  -- Join to find answers to questions
),
PostScoreRank AS (
    SELECT Id,
           Title,
           Score,
           ViewCount,
           OwnerUserId,
           ROW_NUMBER() OVER (PARTITION BY OwnerUserId ORDER BY Score DESC) AS UserRank,
           RANK() OVER (ORDER BY Score DESC) AS GlobalRank
    FROM Posts
    WHERE PostTypeId = 1  -- Only questions
),
ActiveUsers AS (
    SELECT Id,
           DisplayName,
           SUM(COALESCE(UpVotes, 0)) AS TotalUpVotes,
           SUM(COALESCE(DownVotes, 0)) AS TotalDownVotes
    FROM Users
    WHERE Reputation > 1000  -- Active users with high reputation
    GROUP BY Id, DisplayName
),
TopTags AS (
    SELECT tag.TagName,
           COUNT(p.Id) AS PostCount
    FROM Tags tag
    JOIN Posts p ON p.Tags LIKE '%' + tag.TagName + '%'
    GROUP BY tag.TagName
    ORDER BY PostCount DESC
    OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY  -- Top 5 tags
)
SELECT p.Title AS QuestionTitle,
       u.DisplayName AS UserDisplayName,
       p.Score,
       p.ViewCount,
       COALESCE(ph.CloseReason, 'N/A') AS CloseReason,
       t.TagName,
       CASE 
           WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Accepted Answer Exists'
           ELSE 'No Accepted Answer'
       END AS AnswerStatus,
       r.Level AS PostLevel,
       r.GlobalRank
FROM RecursivePostCTE r
JOIN Posts p ON r.Id = p.Id
JOIN Users u ON p.OwnerUserId = u.Id
LEFT JOIN (
    SELECT ph.PostId,
           STRING_AGG(cr.Name, ', ') AS CloseReason
    FROM PostHistory ph
    JOIN CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE ph.PostHistoryTypeId IN (10, 11)  -- Only consider closing and reopening events
    GROUP BY ph.PostId
) ph ON p.Id = ph.PostId
JOIN TopTags t ON t.PostCount > 0  -- Join to get tag information

WHERE u.Reputation > 5000  -- Filter for highly reputable users
ORDER BY p.Score DESC, u.TotalUpVotes - u.TotalDownVotes DESC;
