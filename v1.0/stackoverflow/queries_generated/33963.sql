WITH RecursivePostCounts AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Posts.PostTypeId,
        COUNT(DISTINCT Comments.Id) AS CommentCount,
        COUNT(DISTINCT Votes.Id) AS VoteCount,
        SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    GROUP BY 
        Posts.Id, Posts.Title, Posts.PostTypeId
),
PostHistorySummary AS (
    SELECT 
        PostId,
        COUNT(*) AS HistoryEntryCount,
        MAX(PostHistory.CreationDate) AS LastEditedOn
    FROM 
        PostHistory
    GROUP BY 
        PostId
),
TopUsers AS (
    SELECT 
        Users.Id,
        Users.DisplayName,
        SUM(Users.UpVotes) AS TotalUpVotes,
        SUM(Users.DownVotes) AS TotalDownVotes
    FROM 
        Users
    JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    GROUP BY 
        Users.Id, Users.DisplayName
    HAVING 
        SUM(Users.UpVotes) > 10 -- Arbitrary threshold for top users
)
SELECT 
    p.PostId,
    p.Title,
    p.CommentCount AS TotalComments,
    ph.HistoryEntryCount,
    ph.LastEditedOn,
    u.DisplayName AS Owner,
    u.TotalUpVotes,
    u.TotalDownVotes,
    CASE 
        WHEN p.PostTypeId = 1 AND p.VoteCount > 0 THEN 'Question with Votes'
        WHEN p.PostTypeId = 2 THEN 'Answer'
        ELSE 'Other'
    END AS PostCategory,
    COALESCE(tg.TagName, 'No Tags') AS TagName
FROM 
    RecursivePostCounts p
LEFT JOIN 
    PostHistorySummary ph ON p.PostId = ph.PostId
LEFT JOIN 
    Users u ON p.PostTypeId IN (1, 2) AND u.Id = p.PostId
LEFT JOIN (
    SELECT 
        PostId,
        STRING_AGG(Tags.TagName, ', ') AS TagName
    FROM 
        Posts
    JOIN 
        Tags ON Posts.Tags LIKE CONCAT('%', Tags.TagName, '%')
    GROUP BY 
        PostId
) tg ON tg.PostId = p.PostId
ORDER BY 
    p.CommentCount DESC, p.VoteCount DESC
FETCH FIRST 20 ROWS ONLY;
