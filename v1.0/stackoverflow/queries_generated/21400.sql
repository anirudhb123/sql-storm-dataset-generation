WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY UpVotes DESC) AS UserRank
    FROM UserActivity
),
PostData AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagsList,
        COALESCE(ah.Content, 'No Accepted Answer') AS AcceptedAnswer,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        COALESCE(c.CommentCount, 0) AS CommentCount
    FROM Posts p
    LEFT JOIN PostLinks pl ON p.Id = pl.PostId
    LEFT JOIN Tags t ON pl.RelatedPostId = t.Id
    LEFT JOIN (
        SELECT 
            p.Id,
            p.Body AS Content
        FROM Posts p
        WHERE p.PostTypeId = 2 AND p.AcceptedAnswerId IS NOT NULL
    ) ah ON p.AcceptedAnswerId = ah.Id
    LEFT JOIN (
        SELECT 
            ParentId, 
            COUNT(*) AS AnswerCount 
        FROM Posts 
        WHERE PostTypeId = 2 
        GROUP BY ParentId
    ) a ON p.Id = a.ParentId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM Comments 
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount, ah.Content, a.AnswerCount, c.CommentCount
),
FinalReport AS (
    SELECT 
        tu.DisplayName,
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.ViewCount,
        pd.TagsList,
        pd.AcceptedAnswer,
        pd.AnswerCount,
        pd.CommentCount,
        CASE 
            WHEN tu.UserRank <= 10 THEN 'Top Contributor'
            WHEN tu.UserRank <= 30 THEN 'Notable Contributor'
            ELSE 'New Contributor'
        END AS UserContributionLevel
    FROM PostData pd
    JOIN TopUsers tu ON pd.PostId IN (SELECT PostId FROM Posts WHERE OwnerUserId = tu.UserId)
)
SELECT 
    *,
    CASE 
        WHEN pd.ViewCount > 1000 THEN 'Highly Viewed'
        ELSE 'Moderately Viewed'
    END AS ViewCategory,
    CONCAT('Post Created on: ', TO_CHAR(CreationDate, 'YYYY-MM-DD HH24:MI:SS')) AS CreationDateFormatted
FROM FinalReport pd
WHERE UserContributionLevel IN ('Top Contributor', 'Notable Contributor')
ORDER BY PostId DESC
LIMIT 100;
This SQL query generates a comprehensive report of user contributions and associated posts from the StackOverflow schema, featuring advanced constructs such as Common Table Expressions (CTEs), aggregation, window functions, conditional logic, and string manipulation.
