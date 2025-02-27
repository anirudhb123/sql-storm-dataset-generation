
WITH TagSummary AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        GROUP_CONCAT(DISTINCT p.Title) AS PostTitles,
        SUM(COALESCE(c.CommentCount, 0)) AS TotalComments,
        SUM(COALESCE(v.VoteCount, 0)) AS TotalVotes,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON c.PostId = p.Id
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        t.TagName
), 
RankedTags AS (
    SELECT 
        TagName, 
        PostCount, 
        PostTitles, 
        TotalComments, 
        TotalVotes, 
        TotalViews,
        @view_rank := IF(@prev_views = TotalViews, @view_rank, @view_rank + 1) AS ViewRank,
        @prev_views := TotalViews,
        @vote_rank := IF(@prev_votes = TotalVotes, @vote_rank, @vote_rank + 1) AS VoteRank,
        @prev_votes := TotalVotes
    FROM 
        TagSummary,
        (SELECT @view_rank := 0, @prev_views := NULL, @vote_rank := 0, @prev_votes := NULL) r
    ORDER BY 
        TotalViews DESC, TotalVotes DESC
)
SELECT 
    TagName, 
    PostCount, 
    PostTitles, 
    TotalComments,
    TotalVotes,
    TotalViews,
    ViewRank,
    VoteRank
FROM 
    RankedTags
WHERE 
    ViewRank <= 10 OR VoteRank <= 10
ORDER BY 
    GREATEST(ViewRank, VoteRank);
