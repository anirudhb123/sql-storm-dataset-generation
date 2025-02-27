WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        UPD.UserId AS LastEditorId,
        UPD.LastEditDate,
        PH.Comment,
        RANK() OVER (PARTITION BY p.Id ORDER BY PH.CreationDate DESC) AS EditRank,
        STRING_AGG(DISTINCT T.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory PH ON p.Id = PH.PostId
    LEFT JOIN 
        Users UPD ON p.LastEditorUserId = UPD.Id
    LEFT JOIN 
        LATERAL (
            SELECT 
                UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS TagName
        ) T ON TRUE
    WHERE 
        p.PostTypeId = 1 -- Filtering only Questions
    GROUP BY 
        p.Id, UPD.UserId, UPD.LastEditDate, PH.Comment
),

UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.Tags,
    u.DisplayName AS LastEditor,
    rp.LastEditDate,
    rp.Comment AS LastComment,
    ua.UserId,
    ua.DisplayName AS UserDisplayName,
    ua.VoteCount,
    ua.UpVotes,
    ua.DownVotes
FROM 
    RankedPosts rp
JOIN 
    UserActivity ua ON rp.OwnerUserId = ua.UserId
WHERE 
    rp.EditRank = 1 -- Get only the latest edit for each post
ORDER BY 
    rp.CreationDate DESC
LIMIT 100; -- Limit the output for benchmarking
