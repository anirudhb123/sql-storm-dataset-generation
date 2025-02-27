
WITH TagCounts AS (
    SELECT 
        TRIM(value) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><') AS value
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        TRIM(value)
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagCounts
    WHERE 
        PostCount > 5  
),
HighEngagementPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,  
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes  
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '1 year'  
    GROUP BY 
        p.Id, p.Title
),
EngagementStats AS (
    SELECT 
        hp.PostId,
        hp.Title,
        hp.CommentCount,
        hp.UpVotes,
        hp.DownVotes,
        CASE 
            WHEN hp.CommentCount > 10 AND hp.UpVotes > 20 THEN 'Highly Engaging'
            WHEN hp.CommentCount > 5 AND hp.UpVotes > 10 THEN 'Moderately Engaging'
            ELSE 'Less Engaging'
        END AS EngagementLevel
    FROM 
        HighEngagementPosts hp
),
Results AS (
    SELECT 
        tt.TagName,
        ae.Title,
        ae.CommentCount,
        ae.UpVotes,
        ae.DownVotes,
        ae.EngagementLevel
    FROM 
        TopTags tt
    JOIN 
        EngagementStats ae ON ae.Title LIKE '%' + tt.TagName + '%'  
)
SELECT 
    TagName,
    COUNT(*) AS TotalEngagedPosts,
    AVG(CommentCount) AS AvgCommentCount,
    AVG(UpVotes) AS AvgUpVotes,
    AVG(DownVotes) AS AvgDownVotes
FROM 
    Results
GROUP BY 
    TagName
ORDER BY 
    TotalEngagedPosts DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
