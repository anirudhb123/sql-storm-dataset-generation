WITH PostStats AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(UPVOTE_COUNT.UpVotes, 0) AS UpVotes,
        COALESCE(DOWNVOTE_COUNT.DownVotes, 0) AS DownVotes,
        p.CreationDate,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM
        Posts p
    LEFT JOIN (
        SELECT
            PostId,
            COUNT(*) AS UpVotes
        FROM
            Votes
        WHERE
            VoteTypeId = 2 -- UpMod
        GROUP BY
            PostId
    ) UPVOTE_COUNT ON p.Id = UPVOTE_COUNT.PostId
    LEFT JOIN (
        SELECT
            PostId,
            COUNT(*) AS DownVotes
        FROM
            Votes
        WHERE
            VoteTypeId = 3 -- DownMod
        GROUP BY
            PostId
    ) DOWNVOTE_COUNT ON p.Id = DOWNVOTE_COUNT.PostId
    LEFT JOIN
        Tags t ON POSITION(t.TagName IN p.Tags) > 0 -- Checking if TagName exists in Tags field
    GROUP BY
        p.Id, p.Title, p.ViewCount, p.AnswerCount, UPVOTE_COUNT.UpVotes, DOWNVOTE_COUNT.DownVotes
),

UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.OwnerUserId = u.Id THEN 1 ELSE 0 END) AS PostsCreated,
        SUM(CASE WHEN c.UserId = u.Id THEN 1 ELSE 0 END) AS CommentsMade,
        COUNT(b.Id) AS BadgesCount
    FROM
        Users u
    LEFT JOIN
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN
        Comments c ON c.UserId = u.Id
    LEFT JOIN
        Badges b ON b.UserId = u.Id
    GROUP BY
        u.Id, u.DisplayName
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.AnswerCount,
    ps.UpVotes,
    ps.DownVotes,
    ps.Tags,
    ua.DisplayName AS PostOwner,
    ua.PostsCreated,
    ua.CommentsMade,
    ua.BadgesCount
FROM 
    PostStats ps
JOIN 
    UserActivity ua ON ps.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = ua.UserId)
WHERE
    ps.CreationDate >= '2022-01-01' 
ORDER BY 
    ps.ViewCount DESC,
    ps.AnswerCount DESC;
