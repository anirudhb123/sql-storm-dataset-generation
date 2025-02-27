WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpvoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownvoteCount,
        RANK() OVER (ORDER BY p.ViewCount DESC) AS ViewRank,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        ua.DisplayName,
        ua.PostCount,
        ua.QuestionCount,
        ua.AnswerCount,
        ua.Upvotes,
        ua.Downvotes,
        ROW_NUMBER() OVER (ORDER BY ua.PostCount DESC) AS UserRank
    FROM 
        UserActivity ua
    WHERE 
        ua.PostCount > 10
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.Upvotes,
    tu.Downvotes,
    ps.Title AS TopPostTitle,
    ps.ViewCount AS TopPostViewCount,
    ps.CommentCount AS TopPostCommentCount,
    ps.UpvoteCount AS TopPostUpvoteCount,
    ps.DownvoteCount AS TopPostDownvoteCount
FROM 
    TopUsers tu
LEFT JOIN 
    PostStats ps ON tu.UserId = ps.OwnerUserId AND ps.UserPostRank = 1
WHERE 
    tu.UserRank <= 10
ORDER BY 
    tu.UserRank;
