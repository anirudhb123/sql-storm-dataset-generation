WITH PostTagStats AS (
    SELECT
        p.Title AS PostTitle,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        p.Tags,
        ARRAY_AGG(DISTINCT t.TagName) AS AssociatedTags
    FROM
        Posts p
    JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    WHERE
        p.PostTypeId = 1  -- Only questions
    GROUP BY
        p.Id
),
UserActivity AS (
    SELECT
        u.DisplayName AS UserName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        COUNT(DISTINCT a.Id) AS AnswersGiven,
        SUM(v.BountyAmount) AS TotalBounty,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id AND p.PostTypeId = 1  -- Questions
    LEFT JOIN 
        Posts a ON a.OwnerUserId = u.Id AND a.PostTypeId = 2  -- Answers
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY
        u.Id
),
ClosedPosts AS (
    SELECT
        p.Title,
        p.CreationDate,
        ph.CreationDate AS CloseDate,
        ph.Comment AS CloseReason
    FROM
        Posts p
    JOIN 
        PostHistory ph ON ph.PostId = p.Id
    WHERE
        ph.PostHistoryTypeId = 10  -- Posts closed
)
SELECT
    pts.PostTitle,
    pts.CreationDate AS PostCreationDate,
    pts.ViewCount,
    pts.AnswerCount,
    pts.CommentCount,
    pts.FavoriteCount,
    pts.AssociatedTags,
    ua.UserName,
    ua.QuestionsAsked,
    ua.AnswersGiven,
    ua.TotalBounty,
    ua.TotalUpVotes,
    ua.TotalDownVotes,
    cp.CloseDate,
    cp.CloseReason
FROM
    PostTagStats pts
JOIN 
    UserActivity ua ON pts.PostTitle ILIKE '%' || ua.UserName || '%'  -- Find posts related to users based on title
LEFT JOIN 
    ClosedPosts cp ON cp.Title = pts.PostTitle
ORDER BY
    pts.ViewCount DESC, ua.TotalUpVotes DESC
LIMIT 100;
