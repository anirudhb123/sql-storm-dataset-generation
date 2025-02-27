
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,  
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes  
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(DAY, -30, '2024-10-01 12:34:56')  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Tags, u.DisplayName
),
ExplodedTags AS (
    SELECT 
        rp.PostId,
        value AS TagName  
    FROM 
        RecentPosts rp
    CROSS APPLY STRING_SPLIT(rp.Tags, '><')
),
TagStats AS (
    SELECT 
        TagName,
        COUNT(et.PostId) AS PostCount,  
        SUM(rp.UpVotes) AS TotalUpVotes,
        SUM(rp.DownVotes) AS TotalDownVotes
    FROM 
        ExplodedTags et
    JOIN 
        RecentPosts rp ON et.PostId = rp.PostId
    GROUP BY 
        TagName
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.TotalUpVotes,
    ts.TotalDownVotes,
    (ts.TotalUpVotes - ts.TotalDownVotes) AS NetVotes  
FROM 
    TagStats ts
ORDER BY 
    NetVotes DESC
OFFSET 0 ROWS 
FETCH NEXT 10 ROWS ONLY;
