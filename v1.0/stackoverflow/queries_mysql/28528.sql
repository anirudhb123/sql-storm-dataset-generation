
WITH TagData AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        GROUP_CONCAT(SUBSTRING(p.Tags, 2, CHAR_LENGTH(p.Tags) - 2) SEPARATOR ',') AS TagList,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.Tags
),
TagStatistics AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(TagList, ',', numbers.n), ',', -1) AS TagName,
        COUNT(PostId) AS PostCount,
        SUM(CommentCount) AS TotalComments,
        SUM(UpVotes) AS TotalUpVotes,
        SUM(DownVotes) AS TotalDownVotes
    FROM 
        TagData
    JOIN 
        (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 
         UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers ON CHAR_LENGTH(TagList) 
         -CHAR_LENGTH(REPLACE(TagList, ',', '')) >= numbers.n - 1
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalComments,
        TotalUpVotes,
        TotalDownVotes,
        @rank := @rank + 1 AS Rank
    FROM 
        TagStatistics, (SELECT @rank := 0) r
    ORDER BY 
        TotalUpVotes DESC
)
SELECT 
    TagName,
    PostCount,
    TotalComments,
    TotalUpVotes,
    TotalDownVotes
FROM 
    TopTags
WHERE 
    Rank <= 10 
ORDER BY 
    TotalUpVotes DESC;
