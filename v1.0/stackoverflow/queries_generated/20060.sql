WITH UserPostStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.LastActivityDate IS NOT NULL THEN 1 ELSE 0 END) AS ActivePosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
), QuestionStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE((SELECT COUNT(c.Id) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
        (SELECT COUNT(v.Id) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId IN (2, 3)) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS QuestionRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
), TopQuestions AS (
    SELECT 
        qs.PostId,
        qs.Title,
        qs.CommentCount,
        qs.VoteCount,
        ups.DisplayName,
        ups.TotalPosts,
        ups.TotalQuestions,
        ups.TotalAnswers,
        ups.ActivePosts
    FROM 
        QuestionStats qs
    JOIN 
        UserPostStatistics ups ON qs.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ups.UserId)
    WHERE 
        qs.QuestionRank <= 5
), CloseReasonCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(ph.Id) AS CloseReasonCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    GROUP BY 
        p.Id
)
SELECT 
    tq.DisplayName,
    tq.Title,
    tq.CommentCount,
    tq.VoteCount,
    COALESCE(crc.CloseReasonCount, 0) AS CloseReasonCount,
    CASE 
        WHEN COALESCE(crc.CloseReasonCount, 0) > 0 THEN 'Closed'
        ELSE 'Open'
    END AS Status,
    CASE 
        WHEN tq.ActivePosts > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS UserActivity,
    CASE 
        WHEN tq.TotalQuestions > 0 THEN ROUND(CAST(tq.VoteCount AS numeric) / tq.TotalQuestions, 2)
        ELSE NULL
    END AS AverageVotesPerQuestion
FROM 
    TopQuestions tq
LEFT JOIN 
    CloseReasonCounts crc ON tq.PostId = crc.PostId
ORDER BY 
    tq.VoteCount DESC, tq.CommentCount DESC;

This SQL query achieves the following:

1. **CTEs for Organization**: Breaks down the complexity into manageable segments with CTEs that calculate user statistics, question statistics, and counts of close reasons.

2. **Aggregated User Stats**: Creates a summary of user activity and post types, including total posts, questions, and answers.

3. **Question Filtering**: Selects the top five questions per user based on creation date, including their respective comment and vote count.

4. **Closed Post Reasons**: Counts the reasons for closure for each question using a left join on the `PostHistory` table.

5. **Final Projection**: Gathers all the relevant information, creates a logical status label for questions (open/closed), assesses user activity, and computes an average vote per question if applicable.

6. **Ordering**: Orders the final output by vote count and comment count, revealing the most impactful questions first. 

This encapsulated query illustrates complex SQL constructs while maintaining the relationships and data integrity necessary for coherent output.
