WITH TagAnalysis AS (
    SELECT 
        Tags AS TagList,
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS IndividualTag,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Only analyzing Questions
    GROUP BY 
        Tags
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
PostStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseReopenedStatus
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)

SELECT 
    ua.DisplayName,
    ua.QuestionCount,
    ua.UpVotes,
    ua.DownVotes,
    ta.IndividualTag,
    ta.TagCount,
    ps.EditCount,
    ps.LastEditDate,
    ps.CloseReopenedStatus
FROM 
    UserActivity ua
JOIN 
    Posts p ON ua.UserId = p.OwnerUserId
JOIN 
    TagAnalysis ta ON ta.TagList LIKE '%' || p.Tags || '%'
JOIN 
    PostStats ps ON p.Id = ps.PostId
WHERE 
    ps.EditCount > 0  -- Only including posts that have been edited
ORDER BY 
    ua.UpVotes DESC, 
    ps.EditCount DESC;
