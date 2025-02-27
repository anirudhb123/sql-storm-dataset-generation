
WITH TagStats AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        t.Id, t.TagName
),
TopTags AS (
    SELECT 
        TagId,
        TagName,
        PostCount,
        TotalViews,
        CommentCount,
        UpVoteCount,
        DownVoteCount,
        @row_num1 := IF(@prev1 = PostCount, @row_num1, @row_num1 + 1) AS RankByPostCount,
        @prev1 := PostCount,
        @row_num2 := IF(@prev2 = TotalViews, @row_num2, @row_num2 + 1) AS RankByTotalViews,
        @prev2 := TotalViews,
        @row_num3 := IF(@prev3 = UpVoteCount, @row_num3, @row_num3 + 1) AS RankByUpVotes,
        @prev3 := UpVoteCount
    FROM 
        TagStats, (SELECT @row_num1 := 0, @row_num2 := 0, @row_num3 := 0, @prev1 := NULL, @prev2 := NULL, @prev3 := NULL) AS vars
    ORDER BY PostCount DESC, TotalViews DESC, UpVoteCount DESC
)
SELECT 
    TagId,
    TagName,
    PostCount,
    TotalViews,
    CommentCount,
    UpVoteCount,
    DownVoteCount,
    RankByPostCount,
    RankByTotalViews,
    RankByUpVotes
FROM 
    TopTags
WHERE 
    RankByPostCount <= 10 OR 
    RankByTotalViews <= 10 OR 
    RankByUpVotes <= 10
ORDER BY 
    RankByPostCount, RankByTotalViews, RankByUpVotes;
