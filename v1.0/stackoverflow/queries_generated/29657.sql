WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS AuthorDisplayName,
        u.Reputation AS AuthorReputation,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount,
        (SELECT MAX(creationdate) FROM PostHistory ph WHERE ph.PostId = p.Id) AS LastEdited,
        p.CreationDate,
        DATEDIFF(CURRENT_TIMESTAMP, p.CreationDate) AS AgeInDays
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0
),

TagAnalytics AS (
    SELECT 
        TRIM(SUBSTRING(tag.tag_name FROM 2 FOR LENGTH(tag.tag_name) - 2)) AS Tag,
        COUNT(p.Id) AS PostCount,
        SUM(pm.UpVoteCount) AS TotalUpVotes,
        SUM(pm.DownVoteCount) AS TotalDownVotes,
        AVG(pm.CommentCount) AS AvgComments,
        AVG(pm.AgeInDays) AS AvgPostAge
    FROM 
        Tags tag
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || tag.TagName || '%'
    LEFT JOIN 
        PostMetrics pm ON p.Id = pm.PostId
    GROUP BY 
        tag.tag_name
),

TrendingTags AS (
    SELECT 
        Tag,
        PostCount,
        TotalUpVotes,
        TotalDownVotes,
        AvgComments,
        AvgPostAge,
        (TotalUpVotes - TotalDownVotes) AS NetUpVotes
    FROM 
        TagAnalytics
    WHERE 
        PostCount > 10
    ORDER BY 
        NetUpVotes DESC
    LIMIT 10
)

SELECT 
    tt.Tag,
    tt.PostCount,
    tt.TotalUpVotes,
    tt.TotalDownVotes,
    tt.AvgComments,
    tt.AvgPostAge
FROM 
    TrendingTags tt;
