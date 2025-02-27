WITH RecursivePostHistory AS (
    SELECT 
        id,
        postid,
        revisionguid,
        createdate,
        userid,
        userdisplayname,
        posthistorytypeid,
        comment,
        text,
        ROW_NUMBER() OVER (PARTITION BY postid ORDER BY createdate DESC) as rn
    FROM 
        PostHistory
),
UserVoteStats AS (
    SELECT 
        u.Id AS user_id,
        u.DisplayName,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS upvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS downvotes,
        COUNT(v.Id) AS total_votes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostTags AS (
    SELECT
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '><') AS tag_array ON true
    LEFT JOIN 
        Tags t ON t.TagName = tag_array
    GROUP BY 
        p.Id
),
HighScoringUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        (u.UpVotes - u.DownVotes) AS Score
    FROM 
        Users u
    WHERE 
        (u.UpVotes - u.DownVotes) > 100
),
PostActivity AS (
    SELECT 
        p.Id as PostId,
        p.Title,
        COALESCE(ph.comment, 'No comments') AS LastEditComment,
        ROW_NUMBER() OVER (ORDER BY p.LastActivityDate DESC) AS RecentActivityOrder,
        ph.CreationDate AS LastEditDate
    FROM 
        Posts p
    LEFT JOIN 
        RecursivePostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.rn = 1
)
SELECT 
    pa.PostId,
    pa.Title,
    pt.Tags,
    pa.LastEditComment,
    pa.LastEditDate,
    uvs.DisplayName AS EditorName,
    uvs.upvotes,
    uvs.downvotes,
    hs.Score
FROM 
    PostActivity pa
LEFT JOIN 
    UserVoteStats uvs ON pa.PostId = uvs.user_id
LEFT JOIN 
    HighScoringUsers hs ON hs.Id = pa.PostId
JOIN 
    PostTags pt ON pt.PostId = pa.PostId
WHERE 
    hs.Score IS NOT NULL 
ORDER BY 
    hs.Score DESC, pa.LastEditDate DESC;
