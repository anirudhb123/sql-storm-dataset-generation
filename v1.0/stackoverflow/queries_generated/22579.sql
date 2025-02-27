WITH RankedPosts AS (
    SELECT 
        p.Id as PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) as UserPostRank,
        RANK() OVER (ORDER BY p.ViewCount DESC) as GlobalViewRank
    FROM 
        Posts p
),
UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END), 0) as CloseReopenCount,
        COALESCE(SUM(ph.PostHistoryTypeId = 24)::int, 0) AS EditSuggestionsApplied,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvotesGiven,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvotesGiven
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostHistory ph ON ph.UserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    WHERE 
        u.Reputation > 0
    GROUP BY 
        u.Id, u.DisplayName
),
PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.AnswerCount,
        COALESCE(c.Text, '') AS TopComment,
        string_agg(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Tags t ON strpos(p.Tags, concat('<', t.TagName, '>')) > 0
    GROUP BY 
        p.Id, c.Text
)
SELECT 
    u.DisplayName,
    u.CloseReopenCount,
    u.EditSuggestionsApplied,
    r.PostId,
    COALESCE(ps. TopComment, 'No comments') AS TopComment,
    ps.Tags,
    ps.Score,
    ps.AnswerCount,
    r.GlobalViewRank,
    CASE 
        WHEN u.UpvotesGiven > u.DownvotesGiven THEN 'Positive'
        WHEN u.UpvotesGiven < u.DownvotesGiven THEN 'Negative'
        ELSE 'Neutral'
    END AS UserVoteSentiment
FROM 
    UserActivity u
LEFT JOIN 
    RankedPosts r ON u.UserId = r.OwnerUserId
LEFT JOIN 
    PostSummary ps ON r.PostId = ps.PostId
WHERE 
    r.UserPostRank = 1
ORDER BY 
    u.EditSuggestionsApplied DESC, 
    r.GlobalViewRank ASC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
