
WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        t.TagName,
        COUNT(t.TagName) AS TagCount
    FROM 
        Posts p
    JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
         FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) numbers
         WHERE numbers.n <= 1 + LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '><', ''))) AS t ON p.Id = p.Id
    GROUP BY 
        p.Id, p.Title, p.CreationDate, t.TagName
),
PostVoteStats AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        pc.TagName,
        COALESCE(pvs.UpVotes, 0) AS UpVotes,
        COALESCE(pvs.DownVotes, 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        PostTagCounts pc ON p.Id = pc.PostId
    LEFT JOIN 
        PostVoteStats pvs ON p.Id = pvs.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.Score, pc.TagName, pvs.UpVotes, pvs.DownVotes
),
PopularPosts AS (
    SELECT 
        pa.*,
        @row_num := IF(@prev_tag = pa.TagName, @row_num + 1, 1) AS Rank,
        @prev_tag := pa.TagName
    FROM 
        PostActivity pa,
        (SELECT @row_num := 0, @prev_tag := '') AS vars
    ORDER BY 
        pa.TagName, pa.UpVotes DESC, pa.Score DESC
)
SELECT 
    PostId,
    Title,
    TagName,
    UpVotes,
    DownVotes,
    CommentCount,
    RANK() OVER (ORDER BY UpVotes DESC) AS TotalRank
FROM 
    PopularPosts
WHERE 
    Rank <= 5
ORDER BY 
    TagName, UpVotes DESC;
