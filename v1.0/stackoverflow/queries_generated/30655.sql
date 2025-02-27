WITH RecursiveCTE AS (
    -- This CTE retrieves the title and ID of the top 5 questions sorted by score
    SELECT Id, Title, Score, OwnerUserId, 1 AS Level
    FROM Posts
    WHERE PostTypeId = 1
    ORDER BY Score DESC
    LIMIT 5
),
UserVoteStats AS (
    -- This CTE calculates the upvote and downvote counts per user
    SELECT 
        UserId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM Votes
    GROUP BY UserId
),
PostHistoryDetails AS (
    -- This CTE gathers post history details including close reasons for closed posts
    SELECT 
        h.PostId,
        h.CreationDate,
        h.UserId,
        ph.Name AS PostHistoryType,
        h.Comment,
        COUNT(*) OVER(PARTITION BY h.PostId) AS HistoryCount
    FROM PostHistory h
    JOIN PostHistoryTypes ph ON h.PostHistoryTypeId = ph.Id
    WHERE h.PostHistoryTypeId IN (10, 11)
),
AggregateTags AS (
    -- This CTE organizes tag information and their usage
    SELECT 
        Tags.TagName, 
        COUNT(p.Id) AS PostCount
    FROM Tags
    LEFT JOIN Posts p ON p.Tags LIKE '%' || Tags.TagName || '%'
    GROUP BY Tags.TagName
    HAVING COUNT(p.Id) > 0
),
FinalResults AS (
    -- This final CTE collects all relevant data
    SELECT 
        r.Id AS QuestionId,
        r.Title,
        r.Score,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(vs.UpVotes, 0) AS UpVotes,
        COALESCE(vs.DownVotes, 0) AS DownVotes,
        ph.CreationDate AS LastClosedDate,
        COUNT(DISTINCT tg.TagName) AS TagCount,
        MAX(tg.PostCount) AS MostUsedTagCount
    FROM RecursiveCTE r
    LEFT JOIN Users u ON r.OwnerUserId = u.Id
    LEFT JOIN UserVoteStats vs ON u.Id = vs.UserId
    LEFT JOIN PostHistoryDetails ph ON r.Id = ph.PostId
    LEFT JOIN AggregateTags tg ON tg.TagName IN (SELECT unnest(string_to_array(r.Tags, ',')))
    GROUP BY r.Id, r.Title, r.Score, u.DisplayName, vs.UpVotes, vs.DownVotes, ph.CreationDate
)
SELECT 
    *,
    CASE 
        WHEN TagCount > 5 THEN 'Popular'
        WHEN TagCount BETWEEN 2 AND 5 THEN 'Moderate'
        ELSE 'Low'
    END AS TagPopularity
FROM FinalResults
ORDER BY Score DESC, UpVotes DESC;
