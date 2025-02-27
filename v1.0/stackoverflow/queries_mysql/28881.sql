
WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(v.UpVoteCount, 0)) AS TotalUpVotes,
        SUM(COALESCE(v.DownVoteCount, 0)) AS TotalDownVotes,
        AVG(p.ViewCount) AS AverageViews,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM Tags t
    LEFT JOIN Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
        FROM Votes
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE t.TagName IS NOT NULL
    GROUP BY t.TagName
),
PopularTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalUpVotes - TotalDownVotes AS NetVotes,
        AverageViews,
        CommentCount,
        @rankByUpVotes := IF(@prevTotalUpVotes = TotalUpVotes, @rankByUpVotes, @rowNumber) AS RankByUpVotes,
        @prevTotalUpVotes := TotalUpVotes,
        @rowNumber := @rowNumber + 1
    FROM TagStats, (SELECT @rankByUpVotes := 0, @prevTotalUpVotes := -1, @rowNumber := 1) AS vars
    ORDER BY TotalUpVotes DESC
),
RankedTags AS (
    SELECT 
        TagName,
        PostCount,
        NetVotes,
        AverageViews,
        CommentCount,
        RankByUpVotes,
        RANK() OVER (ORDER BY PostCount DESC) AS RankByPosts
    FROM PopularTags
)
SELECT 
    TagName,
    PostCount,
    NetVotes,
    AverageViews,
    CommentCount,
    CASE 
        WHEN RankByUpVotes <= 10 THEN 'Top 10 by UpVotes'
        ELSE 'Not Top 10 by UpVotes'
    END AS UpVoteRanking,
    CASE 
        WHEN RankByPosts <= 10 THEN 'Top 10 by Posts'
        ELSE 'Not Top 10 by Posts'
    END AS PostRanking
FROM RankedTags
WHERE PostCount > 0
ORDER BY NetVotes DESC, PostCount DESC;
