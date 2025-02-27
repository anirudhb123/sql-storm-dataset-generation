WITH PostStats AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(a.AnswerCount, 0) AS TotalAnswers,
        COALESCE(v.UpVotes, 0) AS TotalUpVotes,
        COALESCE(v.DownVotes, 0) AS TotalDownVotes,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS TotalComments,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM
        Posts p
    LEFT JOIN (
        SELECT
            ParentId,
            COUNT(*) AS AnswerCount
        FROM
            Posts
        WHERE
            PostTypeId = 2
        GROUP BY
            ParentId
    ) a ON p.Id = a.ParentId
    LEFT JOIN (
        SELECT
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM
            Votes
        GROUP BY
            PostId
    ) v ON p.Id = v.PostId
    WHERE
        p.PostTypeId = 1
),
TopPosts AS (
    SELECT
        ps.*,
        (TotalUpVotes - TotalDownVotes) AS NetVotes
    FROM
        PostStats ps
    WHERE
        TotalAnswers > 3
),
FinalPostStats AS (
    SELECT
        *,
        RANK() OVER (ORDER BY NetVotes DESC, ViewCount DESC) AS PopularityRank
    FROM
        TopPosts
)
SELECT
    p.PostId,
    p.Title,
    p.CreationDate,
    p.TotalAnswers,
    p.TotalComments,
    p.NetVotes,
    p.PopularityRank,
    u.DisplayName AS OwnerName,
    CASE 
        WHEN p.UserPostRank = 1 THEN 'Latest Post'
        ELSE 'Older Post'
    END AS PostStatus,
    COALESCE(b.Name, 'No Badge') AS UserBadge
FROM
    FinalPostStats p
LEFT JOIN
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN
    Badges b ON u.Id = b.UserId AND b.Class = 1  -- Assuming we are only interested in gold badges
WHERE
    p.PopularityRank <= 10 OR p.TotalComments > 5
ORDER BY
    p.NetVotes DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;  -- Limit to top 10

This SQL query retrieves interesting statistics about top posts from a Stack Overflow-like schema, including various joins, window functions, and conditional logic. The query uses Common Table Expressions (CTEs) to break down the steps: first, it collates post statistics, then filters to include only high-engagement posts, and finally assesses the ranking based on net votes and view counts. It also retrieves user badge information and categorizes posts based on their recency. The final output presents a limited result set of the most popular posts.
